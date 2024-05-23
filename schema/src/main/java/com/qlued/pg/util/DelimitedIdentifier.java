package com.qlued.pg.util;

import lombok.Builder;

import java.util.ArrayList;
import java.util.List;

@Builder
public class DelimitedIdentifier {

    private List<String> fragments = new ArrayList<>();

    @Builder.Default
    private char delimiter = ':';

    public static String of(Object... objects) {
        DelimitedIdentifier.DelimitedIdentifierBuilder dib = DelimitedIdentifier.builder();
        for (Object o : objects) {
            dib.fragment(o);
        }
        return dib.build().toString();
    }

    public static class DelimitedIdentifierBuilder {

        private List<String> fragments = new ArrayList<>();

        public DelimitedIdentifierBuilder fragment(Object o) {
            fragments.add(o.toString());
            return this;
        }
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        for (String fragment : fragments) {
            if (sb.length() == 0) {
                sb.append(fragment);
            } else {
                sb.append(delimiter);
                sb.append(fragment);
            }
        }
        return sb.toString();
    }
}
