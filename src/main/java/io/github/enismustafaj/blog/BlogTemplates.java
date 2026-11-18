package io.github.enismustafaj.blog;

import java.util.Locale;
import java.util.Map;

import dev.danvega.beansprout.web.ThemeRenderer;
import org.thymeleaf.ITemplateEngine;
import org.thymeleaf.context.Context;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
class BlogTemplates {

    @Bean
    ThemeRenderer blogTheme(ITemplateEngine thymeleaf) {
        return (template, page) -> thymeleaf.process("blog/" + template,
                new Context(Locale.ENGLISH, Map.of("page", page)));
    }
}
