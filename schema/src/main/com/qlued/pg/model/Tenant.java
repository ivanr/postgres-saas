package com.qlued.pg.model;

import lombok.AllArgsConstructor;
import lombok.Data;

@AllArgsConstructor
@Data
public class Tenant {
    private String tenantId;
    private String name;
}
