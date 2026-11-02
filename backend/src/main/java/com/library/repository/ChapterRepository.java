package com.library.repository;
import com.library.entity.Chapter; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface ChapterRepository extends JpaRepository<Chapter,Long> { List<Chapter> findByBookIdOrderByChapterNumber(Long bookId); }
