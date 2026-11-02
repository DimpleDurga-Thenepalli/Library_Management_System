package com.library.controller;
import com.library.dto.Requests.UserView; import com.library.repository.UserRepository;
import org.springframework.web.bind.annotation.*; import org.springframework.security.web.csrf.CsrfToken; import java.security.Principal; import java.util.Map;
@RestController @RequestMapping("/api/auth")
public class AuthController {
 private final UserRepository users; public AuthController(UserRepository users){this.users=users;}
 @GetMapping("/csrf") public Map<String,String> csrf(CsrfToken token){return Map.of("token",token.getToken(),"headerName",token.getHeaderName());}
 @GetMapping("/me") public UserView me(Principal p){return UserView.of(users.findByUsername(p.getName()).orElseThrow());}
}
