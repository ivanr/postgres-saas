package com.qlued.pg.model;

import lombok.AllArgsConstructor;
import lombok.Data;

@AllArgsConstructor
@Data
public class TenantNote {
    private String tenantId;
    private String note;
}
