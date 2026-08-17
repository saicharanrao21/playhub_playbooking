import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = req.headers['x-request-id'] || uuidv4();

    // Validate length and format to prevent malicious oversized IDs
    if (typeof requestId === 'string' && requestId.length > 64) {
       req['requestId'] = uuidv4();
    } else {
       req['requestId'] = requestId;
    }

    res.setHeader('x-request-id', req['requestId']);
    next();
  }
}
