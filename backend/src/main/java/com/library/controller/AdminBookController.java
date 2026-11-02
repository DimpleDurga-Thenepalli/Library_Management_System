package com.library.controller;
import com.library.service.LibraryService; import com.library.entity.*; import com.library.dto.Requests.*;
import org.springframework.web.bind.annotation.*; import org.springframework.web.multipart.MultipartFile; import jakarta.validation.Valid; import java.util.*; import java.io.*; import javax.imageio.ImageIO;
@RestController @RequestMapping("/api/admin/books")
public class AdminBookController {
 private final LibraryService lib; public AdminBookController(LibraryService lib){this.lib=lib;}
 @PostMapping @ResponseStatus(org.springframework.http.HttpStatus.CREATED) public Book create(@Valid @RequestBody BookInput d){return lib.save(null,d);}
 @PutMapping("/{id}") public Book update(@PathVariable Long id,@Valid @RequestBody BookInput d){return lib.save(id,d);}
 @DeleteMapping("/{id}") @ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT) public void delete(@PathVariable Long id){lib.delete(id);}
 @PutMapping("/{id}/status") public Book status(@PathVariable Long id,@RequestBody StatusInput d){return lib.publish(id,d.published());}
 @PostMapping("/{id}/chapters") @ResponseStatus(org.springframework.http.HttpStatus.CREATED) public Chapter chapter(@PathVariable Long id,@Valid @RequestBody ChapterInput d){return lib.saveChapter(id,null,d);}
 @PutMapping("/{id}/chapters/{chapterId}") public Chapter chapter(@PathVariable Long id,@PathVariable Long chapterId,@Valid @RequestBody ChapterInput d){return lib.saveChapter(id,chapterId,d);}
 @DeleteMapping("/{id}/chapters/{chapterId}") @ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT) public void deleteChapter(@PathVariable Long id,@PathVariable Long chapterId){lib.deleteChapter(id,chapterId);}
 @PutMapping("/{id}/chapters/order") public void order(@PathVariable Long id,@RequestBody List<Long> ids){lib.reorder(id,ids);}
 @PostMapping("/{id}/cover") public Book cover(@PathVariable Long id,@RequestParam("file") MultipartFile file) throws IOException {
  if(file.isEmpty()||file.getSize()>5*1024*1024)throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,"Choose an image under 5 MB");
  try(var input=ImageIO.createImageInputStream(file.getInputStream())) {
   var readers=ImageIO.getImageReaders(input);if(!readers.hasNext())throw new IOException("Invalid image");var reader=readers.next();
   try {reader.setInput(input);if(reader.getWidth(0)>4000||reader.getHeight(0)>4000)throw new IOException("Image dimensions exceed 4000 pixels");var image=reader.read(0);var out=new ByteArrayOutputStream();ImageIO.write(image,"png",out);return lib.cover(id,"data:image/png;base64,"+Base64.getEncoder().encodeToString(out.toByteArray()));}finally{reader.dispose();}
  }catch(IOException e){throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,"Use a valid PNG or JPEG image, at most 4000 × 4000 pixels");}
 }
}
