package com.library.config;
import org.springframework.web.bind.annotation.*; import org.springframework.http.*; import org.springframework.web.server.ResponseStatusException; import org.springframework.web.bind.MethodArgumentNotValidException; import org.springframework.dao.DataIntegrityViolationException; import java.util.Map;
@RestControllerAdvice
public class ApiErrors {
 @ExceptionHandler(MethodArgumentNotValidException.class) ResponseEntity<?> validation(MethodArgumentNotValidException e){return ResponseEntity.badRequest().body(Map.of("message",e.getBindingResult().getFieldErrors().stream().map(f->f.getField()+": "+f.getDefaultMessage()).findFirst().orElse("Invalid input")));}
 @ExceptionHandler(DataIntegrityViolationException.class) ResponseEntity<?> conflict(){return ResponseEntity.status(409).body(Map.of("message","Username, email or ISBN already exists, or a related record changed. Refresh and try again."));}
 @ExceptionHandler(ResponseStatusException.class) ResponseEntity<?> status(ResponseStatusException e){return ResponseEntity.status(e.getStatusCode()).body(Map.of("message",ObjectsSafe.message(e.getReason())));}
 @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class) ResponseEntity<?> upload(){return ResponseEntity.status(413).body(Map.of("message","Cover image must be under 5 MB"));}
 private static class ObjectsSafe {static String message(String s){return s==null?"Request failed":s;}}
}
