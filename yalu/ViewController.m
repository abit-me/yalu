//
//  ViewController.m
//  yalu
//
//  Created by A on 2018/1/22.
//  Copyright © 2018年 A. All rights reserved.
//

#import "ViewController.h"

#import <mach/mach.h>
#import <sys/mman.h>
#import <pthread.h>
#import <mach-o/loader.h>

#import "offsets.h"
#import "Jailbreak.h"
#import "Corruption.h"
#import "Bootstrap.h"

@interface ViewController ()
@property(nonatomic, strong) UIButton *jbBtn;
//@property(nonatomic, strong) UIButton *bsBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect sRect = [[UIScreen mainScreen] bounds];
    CGSize sSize = sRect.size;
    CGFloat jbBtnW = 200;
    CGFloat jbBtnH = 55;
    
    CGRect jbBtnRect = CGRectMake(sSize.width/2-jbBtnW/2, sSize.height/2-jbBtnH/2-20, jbBtnW, jbBtnH);
    self.jbBtn = [[UIButton alloc] initWithFrame:jbBtnRect];
    self.jbBtn.backgroundColor = [UIColor yellowColor];
    [self.jbBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.jbBtn addTarget:self action:@selector(startJailbreak) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.jbBtn];
    
    bool jbed = init_offsets();
    if (jbed == true) {
        [self.jbBtn setTitle:@"already jailbreaked" forState:UIControlStateNormal];
        self.jbBtn.enabled = NO;
    } else if (jbed == false) {
        [self.jbBtn setTitle:@"jailbreak" forState:UIControlStateNormal];
        self.jbBtn.enabled = YES;
    }
    
//    CGFloat bsBtnW = 200;
//    CGFloat bsBtnH = 55;
//    CGRect bsBtnRect = CGRectMake(sSize.width/2-bsBtnW/2, CGRectGetMaxY(jbBtnRect)+10, bsBtnW, bsBtnH);
//    self.bsBtn = [[UIButton alloc] initWithFrame:bsBtnRect];
//    self.bsBtn.backgroundColor = [UIColor yellowColor];
//    [self.bsBtn setTitle:@"bootstrap" forState:UIControlStateNormal];
//    [self.bsBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    [self.bsBtn addTarget:self action:@selector(startBootstrap) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.bsBtn];
}

- (void)showErrAlertView:(NSString *)errStr {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"❌" message:errStr preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"I'm wrong" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)startJailbreak {
    
    mach_port_t foundport = find_port();
    if (foundport == 0) {
        [self.jbBtn setTitle:@"failed, retry" forState:UIControlStateNormal];
        return;
    }
    NSLog(@"found corruption %x", foundport);
    
    kern_return_t kret = get_clock(foundport);
    if (kret == KERN_FAILURE) {
        [self.jbBtn setTitle:@"failed, retry" forState:UIControlStateNormal];
        return;
    }
    
    corp_ret_t cort_ret = corruption(foundport);
    exploit(cort_ret.pt, cort_ret.kernel_base, get_allproc_offset());
}

- (void)startBootstrap {
    
    copy_bootstrap();
    run_bootstrap();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
