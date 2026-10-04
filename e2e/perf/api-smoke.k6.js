import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.BASE_URL || 'http://127.0.0.1:3000';

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<800'],
  },
};

export default function apiSmoke() {
  const health = http.get(`${baseUrl}/backend/health`);
  check(health, { 'health 200': (r) => r.status === 200 });

  const root = http.get(`${baseUrl}/backend/`);
  check(root, { 'backend root 200': (r) => r.status === 200 });

  sleep(0.2);
}
