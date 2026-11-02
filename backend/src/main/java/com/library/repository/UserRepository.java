package com.library.repository;
import com.library.entity.LibraryUser; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface UserRepository extends JpaRepository<LibraryUser,Long> { Optional<LibraryUser> findByUsername(String username); List<LibraryUser> findByRoleOrderByIdDesc(String role); }
