package com.library.entity;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
@Entity @Table(name="users") @Getter @Setter @NoArgsConstructor
public class LibraryUser {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 private String fullName; private String username; private String email; private String phoneNumber;
 private String passwordHash; private String role; @Column(name="is_active") private boolean active=true;
 private Instant createdAt=Instant.now();
}
