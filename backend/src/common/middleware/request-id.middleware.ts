import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as crypto from 'crypto';

@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = req.headers['x-request-id'] || crypto.randomUUID();

    // Validate length and format to prevent malicious oversized IDs
    if (typeof requestId === 'string' && requestId.length > 64) {
       req['requestId'] = crypto.randomUUID();
    } else {
       req['requestId'] = requestId;
    }

    res.setHeader('x-request-id', req['requestId']);
    next();
  }
}
