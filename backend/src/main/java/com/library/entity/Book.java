package com.library.entity;
import jakarta.persistence.*; import lombok.*; import java.time.*; import java.math.BigDecimal;
@Entity @Table(name="books") @Getter @Setter @NoArgsConstructor
public class Book {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 private String title; private String author; private String isbn; private String genre;
 @Column(columnDefinition="text") private String description;
 private BigDecimal price; @Column(columnDefinition="text") private String coverImagePath;
 private LocalDate publicationDate; private String status="DRAFT"; private Instant createdAt=Instant.now();
}
