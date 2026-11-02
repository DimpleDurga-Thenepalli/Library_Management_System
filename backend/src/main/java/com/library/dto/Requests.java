package com.library.dto;
import jakarta.validation.constraints.*; import java.math.BigDecimal; import java.time.LocalDate;
public class Requests {
 public record BookInput(@NotBlank @Size(max=200) String title,@NotBlank @Size(max=150) String author,@Size(max=30) String isbn,@NotBlank @Size(max=80) String genre,@NotBlank @Size(max=10000) String description,@NotNull @DecimalMin("0.00") @Digits(integer=10,fraction=2) BigDecimal price,LocalDate publicationDate) {}
 public record ChapterInput(@NotBlank @Size(max=200) String title,@NotBlank @Size(max=500000) String content) {}
 public record CustomerInput(@NotBlank @Size(max=120) String fullName,@Pattern(regexp="[a-zA-Z0-9_.-]{3,60}") @NotBlank String username,@NotBlank @Email @Size(max=254) String email,@Size(max=30) String phoneNumber,boolean active,@Size(max=72) String password) {}
 public record PasswordInput(@NotBlank @Size(min=10,max=72) String password) {}
 public record StatusInput(boolean published) {}
 public record ActiveInput(boolean active) {}
 public record ProgressInput(@NotNull Long chapterId) {}
 public record UserView(Long id,String fullName,String username,String email,String phoneNumber,String role,boolean active) {
  public static UserView of(com.library.entity.LibraryUser u) { return new UserView(u.getId(),u.getFullName(),u.getUsername(),u.getEmail(),u.getPhoneNumber(),u.getRole(),u.isActive()); }
 }
}
