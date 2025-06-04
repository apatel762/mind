package com.aspatel.mind.presentation.web.view;

import io.avaje.jsonb.Json;

/**
 * A temporary object to hold some arbitrary data; used to test that everything is wired up
 * correctly.
 */
@Json
public record HomepageView(String first, String second) {}
