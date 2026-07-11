import type { APIRequestContext, APIResponse } from '@playwright/test';

export interface ApiFetchResponse {
  ok: boolean;
  status: number;
  text(): Promise<string>;
  json(): Promise<unknown>;
}

let playwrightRequest: APIRequestContext | null = null;

/** Route REST seeding through the browser context (shares WAF cookies on live UAT). */
export function setPlaywrightApiRequest(ctx: APIRequestContext | null): void {
  playwrightRequest = ctx;
}

function wrapPlaywrightResponse(res: APIResponse): ApiFetchResponse {
  return {
    ok: res.ok(),
    status: res.status(),
    text: () => res.text(),
    json: () => res.json(),
  };
}

function wrapNodeResponse(res: Response): ApiFetchResponse {
  return {
    ok: res.ok,
    status: res.status,
    text: () => res.text(),
    json: () => res.json(),
  };
}

export async function apiFetch(
  url: string,
  init: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  } = {},
): Promise<ApiFetchResponse> {
  if (playwrightRequest) {
    const res = await playwrightRequest.fetch(url, {
      method: init.method,
      headers: init.headers,
      data: init.body,
    });
    return wrapPlaywrightResponse(res);
  }

  const res = await fetch(url, init);
  return wrapNodeResponse(res);
}
