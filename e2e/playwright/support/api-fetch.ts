import type { APIRequestContext, APIResponse, Page } from '@playwright/test';
import { isLiveUatTarget } from './hosting';
import { e2eBypassHeadersForUrl } from './e2e-bypass';

export interface ApiFetchResponse {
  ok: boolean;
  status: number;
  text(): Promise<string>;
  /**
   * Keep callers compatible while making response shapes explicit at use sites.
   * `unknown` prevents an untyped endpoint response from silently becoming `any`.
   */
  json<T = unknown>(): Promise<T>;
}

let playwrightPage: Page | null = null;
let playwrightRequest: APIRequestContext | null = null;

/** Route REST seeding through the open Playwright page on live UAT. */
export function setPlaywrightPage(page: Page | null): void {
  playwrightPage = page;
}

/** Fallback transport when browser fetch is unavailable. */
export function setPlaywrightApiRequest(ctx: APIRequestContext | null): void {
  playwrightRequest = ctx;
}

function wrapPlaywrightResponse(res: APIResponse): ApiFetchResponse {
  return {
    ok: res.ok(),
    status: res.status(),
    text: () => res.text(),
    json: <T = unknown>() => res.json() as Promise<T>,
  };
}

function wrapNodeResponse(res: Response): ApiFetchResponse {
  return {
    ok: res.ok,
    status: res.status,
    text: () => res.text(),
    json: <T = unknown>() => res.json() as Promise<T>,
  };
}

function wrapBrowserResult(result: { ok: boolean; status: number; text: string }): ApiFetchResponse {
  return {
    ok: result.ok,
    status: result.status,
    text: async () => result.text,
    json: async <T = unknown>() => JSON.parse(result.text) as T,
  };
}

async function browserApiFetch(
  url: string,
  init: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  },
): Promise<ApiFetchResponse> {
  const result = await playwrightPage!.evaluate(
    async ({ fetchUrl, fetchInit }) => {
      const res = await fetch(fetchUrl, {
        method: fetchInit.method ?? 'GET',
        headers: fetchInit.headers,
        body: fetchInit.body,
        credentials: 'include',
      });
      return { ok: res.ok, status: res.status, text: await res.text() };
    },
    { fetchUrl: url, fetchInit: init },
  );
  return wrapBrowserResult(result);
}

export async function apiFetch(
  url: string,
  init: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  } = {},
): Promise<ApiFetchResponse> {
  const headers = {
    ...init.headers,
    ...e2eBypassHeadersForUrl(url),
  };
  const requestInit = { ...init, headers };

  if (playwrightPage && isLiveUatTarget()) {
    return browserApiFetch(url, requestInit);
  }

  if (playwrightRequest) {
    const res = await playwrightRequest.fetch(url, {
      method: requestInit.method,
      headers: requestInit.headers,
      data: requestInit.body,
    });
    return wrapPlaywrightResponse(res);
  }

  const res = await fetch(url, requestInit);
  return wrapNodeResponse(res);
}

export function clearApiFetchTransports(): void {
  playwrightPage = null;
  playwrightRequest = null;
}
