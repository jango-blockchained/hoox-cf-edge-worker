/// <reference types="@cloudflare/workers-types" />

export interface Env {
    // Add your environment variables here
    API_KEY?: string;
    DATABASE?: D1Database;
    KV_STORE?: KVNamespace;
}

export interface ErrorResponse {
    error: string;
    status: number;
}

export interface SuccessResponse<T> {
    data: T;
    status: number;
}

export type ApiResponse<T> = Response | ErrorResponse | SuccessResponse<T>;

export interface RequestWithEnv extends Request {
    env?: Env;
} 