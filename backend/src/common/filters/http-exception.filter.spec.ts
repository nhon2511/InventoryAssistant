import { HttpException, HttpStatus } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AllExceptionsFilter } from './http-exception.filter.js';

describe('AllExceptionsFilter', () => {
  let filter: AllExceptionsFilter;

  beforeEach(() => {
    filter = new AllExceptionsFilter();
  });

  it('should format HttpException correctly', () => {
    const statusMock = vi.fn().mockReturnThis();
    const jsonMock = vi.fn();
    const hostMock = {
      switchToHttp: () => ({
        getResponse: () => ({ status: statusMock, json: jsonMock }),
        getRequest: () => ({ method: 'GET', url: '/test' }),
      }),
    };

    const exception = new HttpException('Forbidden', HttpStatus.FORBIDDEN);
    filter.catch(exception, hostMock as any);

    expect(statusMock).toHaveBeenCalledWith(403);
    expect(jsonMock).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        statusCode: 403,
        message: 'Forbidden',
        path: '/test',
      }),
    );
  });
});
