package com.library.entity;
import jakarta.persistence.*; import lombok.*; import java.time.Instant;
@Entity @Table(name="reading_progress") @Getter @Setter @NoArgsConstructor
public class ReadingProgress {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 private Long userId; private Long bookId; private Long chapterId; private Instant lastReadAt=Instant.now();
}
