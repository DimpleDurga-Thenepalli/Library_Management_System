package com.library.controller;
import com.library.service.LibraryService; import com.library.entity.*; import com.library.dto.Requests.*;
import org.springframework.web.bind.annotation.*; import org.springframework.security.core.Authentication; import jakarta.validation.Valid; import java.util.*;
@RestController @RequestMapping("/api/books")
public class BookController {
 private final LibraryService lib; public BookController(LibraryService lib){this.lib=lib;}
 private boolean admin(Authentication a){return a.getAuthorities().stream().anyMatch(g->g.getAuthority().equals("ROLE_ADMIN"));}
 @GetMapping public List<Book> all(Authentication a){return lib.catalog(admin(a));}
 @GetMapping("/{id}") public Book get(@PathVariable Long id,Authentication a){return lib.book(id,admin(a));}
 @GetMapping("/{id}/chapters") public List<Chapter> chapters(@PathVariable Long id,Authentication a){return lib.chapters(id,admin(a));}
 @GetMapping("/{id}/progress") public ReadingProgress progress(@PathVariable Long id,Authentication a){return lib.progress(a.getName(),id,admin(a));}
 @PutMapping("/{id}/progress") public ReadingProgress progress(@PathVariable Long id,@Valid @RequestBody ProgressInput d,Authentication a){return lib.saveProgress(a.getName(),id,d.chapterId(),admin(a));}
}
