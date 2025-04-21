import { davinci } from "@forgerock/davinci-client";

type Awaited<T> = T extends Promise<infer U> ? U : T;
export type DaVinciClient = Awaited<ReturnType<typeof davinci>>;
export type DaVinciNode = Awaited<ReturnType<Awaited<ReturnType<typeof davinci>>["next"]>>;
