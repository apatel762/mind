package com.aspatel.mind.presentation.web.controller;

import com.aspatel.mind.presentation.web.view.HomepageView;
import io.avaje.http.api.Controller;
import io.avaje.http.api.Get;
import io.avaje.http.api.Path;

@Path("/")
@Controller
public class HomepageController {

  @Get
  HomepageView index() {
    return new HomepageView("Hello", "world!");
  }
}
