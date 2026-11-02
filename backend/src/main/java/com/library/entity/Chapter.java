package com.library.entity;
import jakarta.persistence.*; import lombok.*;
@Entity @Table(name="chapters") @Getter @Setter @NoArgsConstructor
public class Chapter {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 private Long bookId; private Integer chapterNumber; private String title;
 @Column(columnDefinition="text") private String content;
}
