package com.library.controller;
import com.library.service.CustomerService; import com.library.dto.Requests.*; import org.springframework.web.bind.annotation.*; import jakarta.validation.Valid; import java.util.*;
@RestController @RequestMapping("/api/admin/customers")
public class CustomerController {
 private final CustomerService service; public CustomerController(CustomerService s){service=s;}
 @GetMapping public List<UserView> all(){return service.all();}
 @PostMapping @ResponseStatus(org.springframework.http.HttpStatus.CREATED) public UserView create(@Valid @RequestBody CustomerInput d){return service.save(null,d);}
 @PutMapping("/{id}") public UserView edit(@PathVariable Long id,@Valid @RequestBody CustomerInput d){return service.save(id,d);}
 @DeleteMapping("/{id}") @ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT) public void delete(@PathVariable Long id){service.delete(id);}
 @PutMapping("/{id}/active") public UserView active(@PathVariable Long id,@RequestBody ActiveInput d){return service.active(id,d.active());}
 @PutMapping("/{id}/password") public void password(@PathVariable Long id,@Valid @RequestBody PasswordInput d){service.password(id,d.password());}
}
