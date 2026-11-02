import axios from 'axios';
export const api=axios.create({baseURL:'/api',withCredentials:true});
let csrf;
export async function refreshCsrf(){csrf=(await api.get('/auth/csrf')).data;}
api.interceptors.request.use(async config=>{if(!['get','head','options'].includes(config.method)){if(!csrf)await refreshCsrf();config.headers[csrf.headerName]=csrf.token;}return config;});
export function message(e){return e.response?.data?.message|| (e.response?.status===403?'Access denied or security token expired. Refresh the page and try again.':e.response?.status===401?'Your session has ended. Please sign in again.':'Unable to connect. Check that the backend is running.');}
