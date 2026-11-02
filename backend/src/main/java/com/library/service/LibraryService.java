package com.library.service;
import com.library.entity.*; import com.library.repository.*; import com.library.dto.Requests.*;
import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException; import org.springframework.http.HttpStatus;
import org.jsoup.Jsoup; import org.jsoup.safety.Safelist; import java.util.*;
@Service @Transactional
public class LibraryService {
 private final BookRepository books; private final ChapterRepository chapters; private final ProgressRepository progress; private final UserRepository users;
 public LibraryService(BookRepository b,ChapterRepository c,ProgressRepository p,UserRepository u){books=b;chapters=c;progress=p;users=u;}
 public static ResponseStatusException missing(){return new ResponseStatusException(HttpStatus.NOT_FOUND,"Record not found");}
 public Book book(Long id,boolean admin){var b=books.findById(id).orElseThrow(LibraryService::missing);if(!admin&&!b.getStatus().equals("PUBLISHED"))throw missing();return b;}
 public List<Book> catalog(boolean admin){return admin?books.findAllByOrderByIdDesc():books.findByStatusOrderByIdDesc("PUBLISHED");}
 public Book save(Long id,BookInput d){var b=id==null?new Book():book(id,true);b.setTitle(d.title().trim());b.setAuthor(d.author().trim());b.setIsbn(d.isbn()==null||d.isbn().isBlank()?null:d.isbn().trim());b.setGenre(d.genre().trim());b.setDescription(d.description());b.setPrice(d.price());b.setPublicationDate(d.publicationDate());return books.save(b);}
 public void delete(Long id){books.delete(book(id,true));}
 public List<Chapter> chapters(Long id,boolean admin){book(id,admin);return chapters.findByBookIdOrderByChapterNumber(id);}
 public Chapter saveChapter(Long bookId,Long id,ChapterInput d){book(bookId,true);var c=id==null?new Chapter():chapter(bookId,id);c.setBookId(bookId);if(id==null)c.setChapterNumber(chapters.findByBookIdOrderByChapterNumber(bookId).size()+1);c.setTitle(d.title().trim());c.setContent(Jsoup.clean(d.content(),Safelist.basic().addTags("h1","h2","h3","h4","h5","h6")));if(Jsoup.parse(c.getContent()).text().isBlank())throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Chapter content is required");return chapters.save(c);}
 private Chapter chapter(Long b,Long c){var ch=chapters.findById(c).orElseThrow(LibraryService::missing);if(!ch.getBookId().equals(b))throw missing();return ch;}
 public void deleteChapter(Long b,Long c){book(b,true);var all=chapters.findByBookIdOrderByChapterNumber(b);if(all.size()==1&&book(b,true).getStatus().equals("PUBLISHED"))throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Unpublish the book before deleting its last chapter");chapters.delete(chapter(b,c));chapters.flush();var rest=chapters.findByBookIdOrderByChapterNumber(b);for(int i=0;i<rest.size();i++)rest.get(i).setChapterNumber(i+1);}
 public void reorder(Long b,List<Long> ids){var all=chapters(b,true);if(ids==null||ids.size()!=all.size()||new HashSet<>(ids).size()!=all.size()||!new HashSet<>(ids).equals(new HashSet<>(all.stream().map(Chapter::getId).toList())))throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Supply every chapter exactly once");for(var c:all)c.setChapterNumber(ids.indexOf(c.getId())+1);}
 public Book publish(Long id,boolean published){var b=book(id,true);if(published&&chapters.findByBookIdOrderByChapterNumber(id).isEmpty())throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Add at least one chapter before publishing");b.setStatus(published?"PUBLISHED":"DRAFT");return b;}
 public ReadingProgress progress(String username,Long b,boolean admin){book(b,admin);return progress.findByUserIdAndBookId(users.findByUsername(username).orElseThrow().getId(),b).orElse(null);}
 public ReadingProgress saveProgress(String username,Long b,Long c,boolean admin){book(b,admin);chapter(b,c);var uid=users.findByUsername(username).orElseThrow().getId();var p=progress.findByUserIdAndBookId(uid,b).orElseGet(ReadingProgress::new);p.setUserId(uid);p.setBookId(b);p.setChapterId(c);p.setLastReadAt(java.time.Instant.now());return progress.save(p);}
 public Book cover(Long id,String data){var b=book(id,true);b.setCoverImagePath(data);return b;}
}
