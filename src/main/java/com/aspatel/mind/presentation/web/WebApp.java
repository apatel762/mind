package com.aspatel.mind.presentation.web;

import io.avaje.inject.BeanScope;
import io.helidon.webserver.WebServer;
import io.helidon.webserver.http.HttpFeature;
import io.helidon.webserver.http.HttpRouting;

public class WebApp {

  /**
   * Entrypoint of the web app
   *
   * @param args command-line args; unused because none are supported.
   */
  public static void main(String[] args) {

    // This 'try-with-resources' block is the IoC container. We need it here to find all the
    // implemented HTTP features, which need to be registered with the web server.
    try (final var beans = BeanScope.builder().build()) {

      final var routes = beans.list(HttpFeature.class);
      final var builder = HttpRouting.builder();

      routes.forEach(builder::addFeature);

      WebServer.builder().addRouting(builder).build().start();
    }
  }
}
