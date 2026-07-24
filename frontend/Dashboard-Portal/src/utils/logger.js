/**
 * Logger seguro — só loga em modo de desenvolvimento.
 * Em produção, import.meta.env.DEV é substituído por false pelo Vite,
 * e o minificador elimina o código morto (dead code elimination).
 */
export function logError(message, error) {
  if (import.meta.env.DEV) {
    console.error(message, error);
  }
}
