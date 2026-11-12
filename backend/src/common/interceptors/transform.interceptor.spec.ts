import { of } from 'rxjs';
import { describe, expect, it } from 'vitest';
import { TransformInterceptor } from './transform.interceptor.js';

describe('TransformInterceptor', () => {
  it('should transform response to structured API envelope', async () => {
    const interceptor = new TransformInterceptor();
    const contextMock = {
      switchToHttp: () => ({
        getResponse: () => ({ statusCode: 200 }),
      }),
    };

    const nextMock = {
      handle: () => of({ message: 'ok' }),
    };

    const result$ = interceptor.intercept(contextMock as any, nextMock as any);
    result$.subscribe((result) => {
      expect(result.success).toBe(true);
      expect(result.statusCode).toBe(200);
      expect(result.data).toEqual({ message: 'ok' });
      expect(result.timestamp).toBeDefined();
    });
  });
});
