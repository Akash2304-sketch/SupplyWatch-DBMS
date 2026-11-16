const API = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5001/api";
export async function apiGet<T>(path: string): Promise<T> {
  const response = await fetch(`${API}${path}`, { cache: "no-store" });
  if (!response.ok) throw new Error(`API request failed (${response.status})`);
  return response.json();
}
