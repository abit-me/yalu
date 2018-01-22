//
//  Corruption.h
//  yalu
//
//  Created by A on 2018/1/22.
//  Copyright © 2018年 A. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    
    mach_port_t pt;
    uint64_t kernel_base;
} corp_ret_t;

mach_port_t find_port();
kern_return_t get_clock(mach_port_t foundport);
corp_ret_t corruption(mach_port_t foundport);

//@interface Corruption : NSObject
//
//@end

