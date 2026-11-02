package com.library.service;
import com.library.entity.LibraryUser; import com.library.repository.UserRepository; import com.library.dto.Requests.*;
import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional; import org.springframework.security.crypto.password.PasswordEncoder; import org.springframework.web.server.ResponseStatusException; import org.springframework.http.HttpStatus; import java.util.*;
@Service @Transactional
public class CustomerService {
 private final UserRepository users; private final PasswordEncoder encoder;
 public CustomerService(UserRepository users,PasswordEncoder encoder){this.users=users;this.encoder=encoder;}
 public List<UserView> all(){return users.findByRoleOrderByIdDesc("CUSTOMER").stream().map(UserView::of).toList();}
 private LibraryUser customer(Long id){return users.findById(id).filter(u->u.getRole().equals("CUSTOMER")).orElseThrow(LibraryService::missing);}
 public UserView save(Long id,CustomerInput d){var u=id==null?new LibraryUser():customer(id);u.setFullName(d.fullName().trim());u.setUsername(d.username().trim());u.setEmail(d.email().trim().toLowerCase(Locale.ROOT));u.setPhoneNumber(d.phoneNumber());u.setActive(d.active());u.setRole("CUSTOMER");if(id==null){validatePassword(d.password());u.setPasswordHash(encoder.encode(d.password()));}return UserView.of(users.save(u));}
 private void validatePassword(String p){if(p==null||p.length()<10||p.getBytes(java.nio.charset.StandardCharsets.UTF_8).length>72)throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Password must have at least 10 characters and at most 72 UTF-8 bytes");}
 public void password(Long id,String p){validatePassword(p);customer(id).setPasswordHash(encoder.encode(p));}
 public UserView active(Long id,boolean active){var u=customer(id);u.setActive(active);return UserView.of(u);}
 public void delete(Long id){users.delete(customer(id));}
}
