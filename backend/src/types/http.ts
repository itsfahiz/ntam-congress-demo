export type AppError = Error & {
  status?: number;
  public?: boolean;
  code?: string;
  type?: string;
  body?: unknown;
};

export function publicError(
  status: number,
  message: string,
  code?: string,
): AppError {
  const error = new Error(message) as AppError;
  error.status = status;
  error.public = true;
  if (code) error.code = code;
  return error;
}
