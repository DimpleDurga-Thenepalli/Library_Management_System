package com.library.repository;
import com.library.entity.ReadingProgress; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface ProgressRepository extends JpaRepository<ReadingProgress,Long> { Optional<ReadingProgress> findByUserIdAndBookId(Long userId,Long bookId); }
