package com.library.repository;
import com.library.entity.Book; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface BookRepository extends JpaRepository<Book,Long> { List<Book> findByStatusOrderByIdDesc(String status); List<Book> findAllByOrderByIdDesc(); }
