import { Socket } from 'socket.io';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

export enum ChatMessageType {
  TEXT = 'TEXT',
  ARRIVAL_ALERT = 'ARRIVAL_ALERT',
  SYSTEM = 'SYSTEM',
  LOCATION = 'LOCATION',
}

export interface AuthenticatedSocket extends Socket {
  data: {
    user?: UserIdentity;
  };
}
