function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

async function request(url, { method = 'GET', body } = {}) {
  const res = await fetch(url, {
    method,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: body ? JSON.stringify(body) : undefined,
  })

  let data = null
  try { data = await res.json() } catch { /* response had no body */ }

  if (!res.ok) {
    const message = data?.errors?.join(', ') || data?.error || `Request failed (${res.status})`
    const err = new Error(message)
    err.status = res.status
    err.data = data
    throw err
  }

  return data
}

export const api = {
  get:   (url)        => request(url),
  post:  (url, body)  => request(url, { method: 'POST', body }),
  patch: (url, body)  => request(url, { method: 'PATCH', body }),
}
