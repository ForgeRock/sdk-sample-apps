package com.forgerock.kotlinapp;
import static org.forgerock.android.auth.Action.AUTHENTICATE;
import static org.forgerock.android.auth.Action.START_AUTHENTICATE;
import android.net.Uri;
import androidx.annotation.NonNull;
import org.forgerock.android.auth.Action;
import org.forgerock.android.auth.FRRequestInterceptor;
import org.forgerock.android.auth.FRUser;
import org.forgerock.android.auth.Request;

public class HeaderInjectRequestInterceptor implements FRRequestInterceptor<Action> {
    @NonNull
    @Override
    public Request intercept(@NonNull Request request, Action tag) {
        if (tag.getType().equals(START_AUTHENTICATE)) {
            return request.newBuilder()
                    .addHeader("uid", "ee40df82-c915-4ea1-a7f7-19cccac26db7")
                    .url(Uri.parse(request.url().toString())
                            .buildUpon()
                            .appendQueryParameter("ForceAuth", "true").toString())
                    .build();
        }
        return request;
    }
}