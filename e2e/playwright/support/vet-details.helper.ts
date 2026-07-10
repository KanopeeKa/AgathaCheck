import { apiUrl, type TestVet } from './api';

/** Fetch a single vet by id; throws when the GET is not successful. */
export async function getVetById(
  baseURL: string,
  token: string,
  vetId: string,
): Promise<TestVet> {
  const res = await fetch(apiUrl(`/vets/${vetId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getVetById failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<TestVet>;
}

/**
 * Partial update for a vet. PUT requires all fields; fetches current vet first
 * with an HTTP status check before merging defaults.
 */
export async function updateVetDetails(
  baseURL: string,
  token: string,
  vetId: string,
  data: Partial<{
    name: string;
    clinic: string;
    phone: string;
    email: string;
    website: string;
    address: string;
    notes: string;
  }>,
): Promise<TestVet> {
  const current = await getVetById(baseURL, token, vetId);

  const res = await fetch(apiUrl(`/vets/${vetId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: data.name ?? current.name,
      clinic: data.clinic ?? current.clinic ?? '',
      phone: data.phone ?? current.phone ?? '',
      email: data.email ?? current.email ?? '',
      website: data.website ?? current.website ?? '',
      address: data.address ?? current.address ?? '',
      notes: data.notes ?? current.notes ?? '',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateVetDetails failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<TestVet>;
}
