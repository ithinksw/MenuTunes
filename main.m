//
//  main.m
//  MenuTunes
//
//  Created by Kent Sutherland on Sun Nov 17 2002.
//  Copyright (c) 2002 Kent Sutherland. All rights reserved.
//
// Poink.
#import <Cocoa/Cocoa.h>
#import <sys/ptrace.h>

static const int (*ptp)(int,int,caddr_t,int) = ptrace;

int main(int argc, const char *argv[])
{
#ifdef MT_RELEASE
    ptp(PT_DENY_ATTACH,getpid(),NULL,0);
#endif
    return NSApplicationMain(argc, argv);
}
