package com.library.security;
import com.library.repository.UserRepository;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
@Configuration
public class SecurityConfig {
 @Bean PasswordEncoder passwords() { return new BCryptPasswordEncoder(); }
 @Bean UserDetailsService users(UserRepository users) { return username -> users.findByUsername(username).map(u -> User.withUsername(u.getUsername()).password(u.getPasswordHash()).roles(u.getRole()).disabled(!u.isActive()).build()).orElseThrow(() -> new UsernameNotFoundException("Invalid credentials")); }
 @Bean SecurityFilterChain security(HttpSecurity http, UserRepository users) throws Exception {
  http.authorizeHttpRequests(a -> a.requestMatchers("/api/auth/csrf","/api/auth/login").permitAll().requestMatchers("/api/admin/**").hasRole("ADMIN").anyRequest().authenticated())
   .formLogin(f -> f.loginProcessingUrl("/api/auth/login").successHandler((req,res,auth) -> {res.setContentType("application/json");res.getWriter().write("{\"ok\":true}");}).failureHandler((req,res,ex) -> {res.setStatus(401);res.setContentType("application/json");res.getWriter().write("{\"message\":\"Invalid credentials or inactive account\"}");}))
   .logout(l -> l.logoutUrl("/api/auth/logout").logoutSuccessHandler((req,res,auth) -> res.setStatus(204)).deleteCookies("JSESSIONID"))
   .exceptionHandling(e -> e.authenticationEntryPoint((req,res,ex) -> res.sendError(401)).accessDeniedHandler((req,res,ex) -> res.sendError(403)))
   .addFilterAfter(new org.springframework.web.filter.OncePerRequestFilter() {
    protected void doFilterInternal(jakarta.servlet.http.HttpServletRequest req,jakarta.servlet.http.HttpServletResponse res,jakarta.servlet.FilterChain chain) throws java.io.IOException,jakarta.servlet.ServletException {
     var auth=org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
     if(auth!=null && auth.isAuthenticated() && !auth.getName().equals("anonymousUser") && users.findByUsername(auth.getName()).filter(com.library.entity.LibraryUser::isActive).isEmpty()) { req.getSession().invalidate();org.springframework.security.core.context.SecurityContextHolder.clearContext();res.sendError(401);return; }
     chain.doFilter(req,res);
    }
   },org.springframework.security.web.authentication.AnonymousAuthenticationFilter.class);
  return http.build();
 }
}
