/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/**
 * A resource created on first use and releasable so a later `get` rebuilds it.
 */
export type LazyResource<T> = {
  get(): T;
  dispose(): Promise<void>;
};

/**
 * Defers construction of a native-backed client until first use.
 *
 * @param create Factory invoked at most once between disposals.
 * @param release Releases the created value's native handles.
 * @returns A lazy handle; `dispose` is a no-op when nothing was created.
 */
export function lazyResource<T>(
  create: () => T,
  release: (value: T) => Promise<void>,
): LazyResource<T> {
  let current: { value: T } | undefined;
  return {
    get() {
      current ??= { value: create() };
      return current.value;
    },
    async dispose() {
      const created = current;
      current = undefined;
      if (created) {
        await release(created.value);
      }
    },
  };
}
