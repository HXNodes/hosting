import { registerResourceWS } from './resources';
 
// This will be set in index.ts after server is created
export let resourceWS: any = null;
export function setResourceWS(ws: any) {
  resourceWS = ws;
} 