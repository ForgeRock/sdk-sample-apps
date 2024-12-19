/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.reactnativetodo

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.module.annotations.ReactModule
import com.google.gson.Gson
import com.google.gson.JsonObject
import org.forgerock.android.auth.AccessToken
import org.forgerock.android.auth.FRAuth
import org.forgerock.android.auth.FRListener
import org.forgerock.android.auth.FROptions
import org.forgerock.android.auth.FROptionsBuilder
import org.forgerock.android.auth.FRUser
import org.forgerock.android.auth.Logger
import org.forgerock.android.auth.Node
import org.forgerock.android.auth.NodeListener
import org.forgerock.android.auth.UserInfo
import org.forgerock.android.auth.callback.AbstractPromptCallback
import org.forgerock.android.auth.callback.BooleanAttributeInputCallback
import org.forgerock.android.auth.callback.Callback
import org.forgerock.android.auth.callback.ChoiceCallback
import org.forgerock.android.auth.callback.DeviceBindingCallback
import org.forgerock.android.auth.callback.DeviceProfileCallback
import org.forgerock.android.auth.callback.DeviceSigningVerifierCallback
import org.forgerock.android.auth.callback.KbaCreateCallback
import org.forgerock.android.auth.callback.NameCallback
import org.forgerock.android.auth.callback.PasswordCallback
import org.forgerock.android.auth.callback.StringAttributeInputCallback
import org.forgerock.android.auth.callback.TermsAndConditionsCallback
import org.forgerock.android.auth.callback.ValidatedPasswordCallback
import org.forgerock.android.auth.callback.ValidatedUsernameCallback
import org.forgerock.android.auth.callback.WebAuthnAuthenticationCallback
import org.forgerock.android.auth.callback.WebAuthnRegistrationCallback
import org.forgerock.android.auth.exception.AuthenticationRequiredException
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.concurrent.Semaphore

/**
 * FRAuthSampleBridge is a React Native bridge module that provides access to the ForgeRock SDK
 * from JavaScript.
 */
@ReactModule(name = "FRAuthSampleBridge")
class FRAuthSampleBridge internal constructor(var context: ReactApplicationContext) :
    ReactContextBaseJavaModule(context) {
    var currentNode: Node? = null
    var listener: NodeListener<*>? = null
    var reactNativePromise: Promise? = null

    override fun getName(): String {
        return "FRAuthSampleBridge"
    }

    /**
     * Initializes the ForgeRock SDK with the provided configuration.
     * @param promise A promise that resolves when the SDK is initialized.
     */
    @ReactMethod
    fun start(promise: Promise) {
        Logger.set(Logger.Level.DEBUG)

        val config = Configuration()
        val options = FROptionsBuilder.build {
            server {
                url = config.amURL
                realm = config.realm
                cookieName = config.cookieName
            }
            oauth {
                oauthClientId = config.oauthClientId
                oauthRedirectUri = config.oauthRedirectURI
                oauthScope = config.oauthScopes
            }
            service {
                authServiceName = config.mainAuthenticationJourney
                registrationServiceName = config.registrationServiceName
            }
        }

        FRAuth.start(this.context, options)
        promise.resolve("SDK Initialized")
    }

    /**
     * Logs out the current user.
     */
    @ReactMethod
    fun logout() {
        val user = FRUser.getCurrentUser()
        user?.logout()
    }

    /**
     * Logs in the user.
     * @param promise A promise that resolves when the user is logged in.
     */
    @ReactMethod
    fun login(promise: Promise) {
        try {
            authenticate(promise, true)
        } catch (e: Exception) {
            promise.reject("error", e.toString(), e)
        }
    }

    /**
     * Registers a new user.
     * @param promise A promise that resolves when the user is registered.
     */
    @ReactMethod
    fun register(promise: Promise) {
        try {
            authenticate(promise, false)
        } catch (e: Exception) {
            promise.reject("error", e.toString(), e)
        }
    }

    /**
     * Retrieves the current user's access token.
     * @param promise A promise that resolves with the access token.
     */
    @ReactMethod
    fun getAccessToken(promise: Promise?) {
        this.reactNativePromise = promise
        if (FRUser.getCurrentUser() != null) {
            FRUser.getCurrentUser().getAccessToken(object : FRListener<AccessToken?> {
                override fun onSuccess(result: AccessToken?) {
                    val gson = Gson()
                    val accessTokenJson = gson.toJson(result)
                    reactNativePromise?.resolve(accessTokenJson)
                }

                override fun onException(e: Exception) {
                    reactNativePromise?.reject("error", e.message, e)
                }
            })
        } else {
            Logger.error("error", "Current user is null. Not logged in or SDK not initialized yet")
            reactNativePromise?.reject(
                "error",
                "Current user is null. Not logged in or SDK not initialized yet"
            )
        }
    }

    /**
     * Retrieves the current user's ID token.
     * @param promise A promise that resolves with the User Info.
     */
    @ReactMethod
    fun getUserInfo(promise: Promise) {
        if (FRUser.getCurrentUser() != null) {
            FRUser.getCurrentUser().getUserInfo(object : FRListener<UserInfo?> {
                override fun onSuccess(result: UserInfo?) {
                    var productMap: WritableMap? = null
                    val jsonResult = result?.raw
                    try {
                        if (jsonResult != null) {
                            productMap = convertJsonToMap(jsonResult)
                        }
                        promise.resolve(productMap)
                    } catch (e: JSONException) {
                        Logger.error("error", e, "getUserInfo Failed")
                        promise.reject("error", e.message, e)
                    }
                }

                override fun onException(e: Exception) {
                    Logger.error("error", e, "getUserInfo Failed")
                    promise.reject("error", e.message, e)
                }
            })
        } else {
            Logger.error("error", "Current user is null. Not logged in or SDK not initialized yet")
            promise.reject(
                "error",
                "Current user is null. Not logged in or SDK not initialized yet"
            )
        }
    }

    /**
     * Retrieves the next node in the authentication flow.
     * @param promise A promise that resolves either with the next node or an error.
     */
    @ReactMethod
    @Throws(InterruptedException::class)
    fun next(response: String?, promise: Promise) {
        this.reactNativePromise = promise
        val gson = Gson()
        val responseObj = gson.fromJson(
            response,
            Response::class.java
        )

        if (responseObj == null) {
            promise.reject("error", "parsing response failed")
            return
        }

        val callbacksList = currentNode?.callbacks ?: run {
            promise.reject("error", "current node or callbacks are null")
            return
        }

        for (i in callbacksList.indices) {
            val nodeCallback: Any = callbacksList[i]
            val responseCallbacks = responseObj.callbacks ?: continue  // Skip if callbacks are null
            for (j in responseCallbacks.indices) {
                val callback = responseCallbacks[j]
                val currentCallbackType = callback.type
                val input = callback.input?.getOrNull(0) ?: continue  // Skip if input is null or empty
                when {
                    currentCallbackType == "NameCallback" && i == j -> {
                        currentNode?.getCallback(NameCallback::class.java)?.setName(input.value as? String)
                    }

                    currentCallbackType == "ValidatedCreateUsernameCallback" && i == j -> {
                        currentNode?.getCallback(ValidatedUsernameCallback::class.java)?.setUsername(input.value as? String)
                    }

                    currentCallbackType == "ValidatedCreatePasswordCallback" && i == j -> {
                        val password = input.value as? String
                        currentNode?.getCallback(ValidatedPasswordCallback::class.java)?.setPassword(password?.toCharArray())
                    }

                    currentCallbackType == "PasswordCallback" && i == j -> {
                        val password = input.value as? String
                        currentNode?.getCallback(PasswordCallback::class.java)?.setPassword(password?.toCharArray())
                    }

                    currentCallbackType == "ChoiceCallback" && i == j -> {
                        val index = input.value as? Int
                        if (index != null) {
                            currentNode?.getCallback(ChoiceCallback::class.java)?.setSelectedIndex(index)
                        }
                    }

                    currentCallbackType == "KbaCreateCallback" && i == j -> {
                        val kba = currentNode?.callbacks?.getOrNull(j) as? KbaCreateCallback ?: continue
                        for (rawInput in callback.input.orEmpty()) {
                            when {
                                rawInput.name?.contains("question") == true -> kba.setSelectedQuestion(rawInput.value as? String)
                                else -> kba.setSelectedAnswer(rawInput.value as? String)
                            }
                        }
                    }

                    currentCallbackType == "StringAttributeInputCallback" && i == j -> {
                        (nodeCallback as? StringAttributeInputCallback)?.value = input.value as? String
                    }

                    currentCallbackType == "BooleanAttributeInputCallback" && i == j -> {
                        (nodeCallback as? BooleanAttributeInputCallback)?.value = input.value as? Boolean
                    }

                    currentCallbackType == "TermsAndConditionsCallback" && i == j -> {
                        val accepted = input.value as? Boolean
                        if (accepted != null) {
                            (nodeCallback as? TermsAndConditionsCallback)?.setAccept(accepted)
                        }
                    }

                    currentCallbackType == "DeviceProfileCallback" && i == j -> {
                        val available = Semaphore(1, true)
                        available.acquire()

                        currentNode?.getCallback(DeviceProfileCallback::class.java)?.execute(context, object : FRListener<Void?> {
                            override fun onSuccess(result: Void?) {
                                Logger.warn("DeviceProfileCallback", "Device Profile Collection Succeeded")
                                available.release()
                            }

                            override fun onException(e: Exception) {
                                Logger.warn("DeviceProfileCallback", e, "Device Profile Collection Failed")
                                available.release()
                            }
                        })
                    }
                }
            }
        }
        currentNode?.next(this.context, listener)

    }

    /**
     * Authenticates the user.
     * @param promise A promise that resolves when the user is authenticated.
     * @param isLogin A boolean that indicates whether the user is logging in or registering.
     */
    fun authenticate(promise: Promise?, isLogin: Boolean) {
        this.reactNativePromise = promise
        val nodeListenerFuture: NodeListener<FRUser?> = object : NodeListener<FRUser?> {
            override fun onSuccess(user: FRUser?) {
                val accessToken: AccessToken
                val map = Arguments.createMap()
                try {
                    accessToken = FRUser.getCurrentUser().accessToken
                    val gson = Gson()
                    val accessTokenJson = gson.toJson(accessToken)
                    map.putString("type", "LoginSuccess")
                    map.putString("sessionToken", accessTokenJson)
                    reactNativePromise?.resolve(map)
                } catch (e: AuthenticationRequiredException) {
                    Logger.warn("customLogin", e, "Login Failed")
                    reactNativePromise?.reject("error", e.localizedMessage, e)
                }
            }

            override fun onException(e: Exception) {
                // Handle Exception
                Logger.warn("customLogin", e, "Login Failed")
                reactNativePromise?.reject("error", e.localizedMessage, e)
            }

            override fun onCallbackReceived(node: Node) {
                listener = this
                currentNode = node

                execute(node, context)

            }
        }

        if (isLogin == true) {
            FRUser.login(this.context, nodeListenerFuture)
        } else {
            FRUser.register(this.context, nodeListenerFuture)
        }
    }

    /**
     * Executes the current node.
     * @param currentNode The current node.
     * @param contextRef The React Native context.
     */
    fun execute(currentNode: Node, contextRef: ReactApplicationContext) {
        for (i in currentNode.callbacks.indices) {
            val nodeCallback: Any = currentNode.callbacks[i]
            if (nodeCallback is WebAuthnRegistrationCallback) {
                nodeCallback.register(context = contextRef, node = currentNode, listener = object : FRListener<Void?> {
                    override fun onSuccess(result: Void?) {
                        Logger.debug("DCA Native ForgeRock", "WebAuthNReg Succeeded")
                        currentNode.next(contextRef, listener)
                    }

                    override fun onException(e: Exception) {
                        Logger.warn("DCA Native ForgeRock", "WebAuthNReg Failed")
                        currentNode.next(contextRef, listener)
                    }
                })
                return
            }
            if (nodeCallback is WebAuthnAuthenticationCallback) {
                nodeCallback.authenticate(context = contextRef, node = currentNode, listener = object : FRListener<Void?> {
                    override fun onSuccess(result: Void?) {
                        Logger.debug(
                            "DCA Native ForgeRock",
                            "WebAuthnAuthenticationCallback Succeeded"
                        )
                        currentNode?.next(contextRef, listener)
                    }
                    override fun onException(e: Exception) {
                        Logger.warn(
                            "DCA Native ForgeRock",
                            "WebAuthnAuthenticationCallback Failed"
                        )
                        currentNode?.next(contextRef, listener)
                    }
                })
                return
            }
            if (nodeCallback is DeviceBindingCallback) {
                nodeCallback.bind(context = contextRef, listener = object : FRListener<Void?> {
                    override fun onSuccess(result: Void?) {
                        Logger.debug("DCA Native ForgeRock", "DeviceBindingCallback Succeeded")
                        currentNode?.next(contextRef, listener)
                    }

                    override fun onException(e: Exception) {
                        Logger.warn("DCA Native ForgeRock", "DeviceBindingCallback Failed")
                        currentNode?.next(contextRef, listener)
                    }
                })
                return
            }
            if (nodeCallback is DeviceSigningVerifierCallback) {
                nodeCallback.sign(context = contextRef, listener = object : FRListener<Void?> {
                    override fun onSuccess(result: Void?) {
                        Logger.debug("DCA Native ForgeRock", "DeviceSigningVerifierCallback Succeeded")
                        currentNode?.next(contextRef, listener)
                    }

                    override fun onException(e: Exception) {
                        Logger.warn("DCA Native ForgeRock", "DeviceSigningVerifierCallback Failed")
                        currentNode?.next(contextRef, listener)
                    }
                })
                return
            }

        }

        val frNode = FRNode(currentNode)
        val gson = Gson()
        val json = gson.toJson(frNode)
        reactNativePromise?.resolve(json)
    }

    companion object {
        @Throws(JSONException::class)
        private fun convertJsonToMap(jsonObject: JSONObject): WritableMap {
            val map: WritableMap = WritableNativeMap()

            val iterator = jsonObject.keys()
            while (iterator.hasNext()) {
                val key = iterator.next()
                val value = jsonObject[key]
                if (value is JSONObject) {
                    map.putMap(key, convertJsonToMap(value))
                } else if (value is JSONArray) {
                    map.putArray(key, convertJsonToArray(value))
                } else if (value is Boolean) {
                    map.putBoolean(key, value)
                } else if (value is Int) {
                    map.putInt(key, value)
                } else if (value is Double) {
                    map.putDouble(key, value)
                } else if (value is String) {
                    map.putString(key, value)
                } else {
                    map.putString(key, value.toString())
                }
            }
            return map
        }

        @Throws(JSONException::class)
        private fun convertJsonToArray(jsonArray: JSONArray): WritableArray {
            val array: WritableArray = WritableNativeArray()

            for (i in 0 until jsonArray.length()) {
                val value = jsonArray[i]
                if (value is JSONObject) {
                    array.pushMap(convertJsonToMap(value))
                } else if (value is JSONArray) {
                    array.pushArray(convertJsonToArray(value))
                } else if (value is Boolean) {
                    array.pushBoolean(value)
                } else if (value is Int) {
                    array.pushInt(value)
                } else if (value is Double) {
                    array.pushDouble(value)
                } else if (value is String) {
                    array.pushString(value)
                } else {
                    array.pushString(value.toString())
                }
            }
            return array
        }

        @Throws(JSONException::class)
        private fun convertMapToJson(readableMap: ReadableMap): JSONObject {
            val `object` = JSONObject()
            val iterator = readableMap.keySetIterator()
            while (iterator.hasNextKey()) {
                val key = iterator.nextKey()
                when (readableMap.getType(key)) {
                    ReadableType.Null -> `object`.put(key, JSONObject.NULL)
                    ReadableType.Boolean -> `object`.put(key, readableMap.getBoolean(key))
                    ReadableType.Number -> `object`.put(key, readableMap.getDouble(key))
                    ReadableType.String -> `object`.put(key, readableMap.getString(key))
                    ReadableType.Map -> `object`.put(
                        key, convertMapToJson(
                            readableMap.getMap(key) ?: WritableNativeMap()
                        )
                    )

                    ReadableType.Array -> `object`.put(
                        key, convertArrayToJson(
                            readableMap.getArray(key) ?: WritableNativeArray()
                        )
                    )
                }
            }
            return `object`
        }

        @Throws(JSONException::class)
        private fun convertArrayToJson(readableArray: ReadableArray): JSONArray {
            val array = JSONArray()
            for (i in 0 until readableArray.size()) {
                when (readableArray.getType(i)) {
                    ReadableType.Null -> {}
                    ReadableType.Boolean -> array.put(readableArray.getBoolean(i))
                    ReadableType.Number -> array.put(readableArray.getDouble(i))
                    ReadableType.String -> array.put(readableArray.getString(i))
                    ReadableType.Map -> array.put(convertMapToJson(readableArray.getMap(i)))
                    ReadableType.Array -> array.put(convertArrayToJson(readableArray.getArray(i)))
                }
            }
            return array
        }
    }
}

/**
 * Configuration is a data class that holds the configuration values for the ForgeRock SDK.
 */
class FRNode(node: Node) {

    private var frCallbacks  = mutableListOf<FRCallback>()

    var authId: String = node.authId

    /** Unique UUID String value of initiated AuthService flow */
    var authServiceId: String = ""

    /** Stage attribute in Page Node */
    var stage: String = node.stage ?: ""

    /** Header attribute in Page Node */
    var pageHeader: String = node.header ?: ""

    /** Description attribute in Page Node */
    var pageDescription: String = node.description ?: ""

    //array of raw callbacks
    private var callbacks: MutableList<JsonObject>

    init {
        this.frCallbacks = ArrayList()
        this.callbacks = ArrayList()
        for (callback in node.callbacks) {
            frCallbacks.add(FRCallback(callback))
            val convertedObject = Gson().fromJson(
                callback.content,
                JsonObject::class.java
            )
            callbacks.add(convertedObject)
        }
    }

    fun getCallbacks(): List<JsonObject> {
        return callbacks
    }

    fun setCallbacks(callbacks: MutableList<JsonObject>) {
        this.callbacks = callbacks
    }

    fun getFrCallbacks(): MutableList<FRCallback> {
        return frCallbacks
    }

    fun setFrCallbacks(callbacks: MutableList<FRCallback>) {
        this.frCallbacks = callbacks
    }
}

/**
 * FRCallback is a data class that holds the Callback values for the ForgeRock SDK.
 */
class FRCallback(callback: Callback) {
    var type: String = callback.type
    var prompt: String? = null
    var choices: List<String>? = null
    var predefinedQuestions: List<String>? = null
    var inputNames: List<String> = ArrayList()

    /** Raw JSON response of Callback */
    var response: String

    init {
        if (callback is AbstractPromptCallback) {
            this.prompt = callback.prompt
        }

        if (callback is KbaCreateCallback) {
            val kbaCreateCallback = callback
            this.prompt = kbaCreateCallback.getPrompt()
            this.predefinedQuestions = kbaCreateCallback.predefinedQuestions
        }

        if (callback is ChoiceCallback) {
            val choiceCallback = callback
            this.prompt = choiceCallback.getPrompt()
            this.choices = choiceCallback.choices
        }

        this.response = callback.content
    }
}

/**
 * Configuration is a data class that holds the Response values for the ForgeRock SDK.
 */
internal class Response {
    var authId: String? = null
    var callbacks: List<RawCallback>? = null
    var status: Int? = null
}

/**
 * Configuration is a data class that holds the RawCallback values for the ForgeRock SDK.
 */
internal class RawCallback {
    var type: String? = null
    var input: List<RawInput>? = null
    var _id: Int? = null
}

/**
 * Configuration is a data class that holds the RawInput values for the ForgeRock SDK.
 */
internal class RawInput {
    var name: String? = null
    var value: Any? = null
}