import {createContext,useContext,useEffect,useState} from 'react';import {api,refreshCsrf} from '../services/api';
const Context=createContext();export const useAuth=()=>useContext(Context);
export function AuthProvider({children}){const [user,setUser]=useState(null),[loading,setLoading]=useState(true);useEffect(()=>{api.get('/auth/me').then(r=>setUser(r.data)).catch(()=>{}).finally(()=>setLoading(false));},[]);
async function login(username,password,role){await refreshCsrf();await api.post('/auth/login',new URLSearchParams({username,password}));await refreshCsrf();const u=(await api.get('/auth/me')).data;if(u.role!==role){await api.post('/auth/logout');await refreshCsrf();throw new Error(`This account is a ${u.role.toLowerCase()}. Select the matching sign-in option.`);}setUser(u);return u;}
async function logout(){await api.post('/auth/logout');setUser(null);await refreshCsrf();}return <Context.Provider value={{user,loading,login,logout}}>{children}</Context.Provider>;}
