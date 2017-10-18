/*
 * (c) Copyright Ascensio System SIA 2010-2017
 *
 * This program is a free software product. You can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License (AGPL)
 * version 3 as published by the Free Software Foundation. In accordance with
 * Section 7(a) of the GNU AGPL its Section 15 shall be amended to the effect
 * that Ascensio System SIA expressly excludes the warranty of non-infringement
 * of any third-party rights.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR  PURPOSE. For
 * details, see the GNU AGPL at: http://www.gnu.org/licenses/agpl-3.0.html
 *
 * You can contact Ascensio System SIA at Lubanas st. 125a-25, Riga, Latvia,
 * EU, LV-1021.
 *
 * The  interactive user interfaces in modified source and object code versions
 * of the Program must display Appropriate Legal Notices, as required under
 * Section 5 of the GNU AGPL version 3.
 *
 * Pursuant to Section 7(b) of the License you must retain the original Product
 * logo when distributing the program. Pursuant to Section 7(e) we decline to
 * grant you any rights under trademark law for use of our trademarks.
 *
 * All the Product's GUI elements, including illustrations and icon sets, as
 * well as technical writing content are licensed under the terms of the
 * Creative Commons Attribution-ShareAlike 4.0 International. See the License
 * terms at http://creativecommons.org/licenses/by-sa/4.0/legalcode
 *
 */
//
//  ASCPresentationReporter.m
//  ONLYOFFICE
//
//  Created by Alexander Yuzhin on 10/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

#import "ASCPresentationReporter.h"
#import "NSCefView.h"
#import "mac_application.h"
#import "NSView+ASCView.h"

@interface ASCPresentationReporter() <NSWindowDelegate>
@property (nonatomic) NSStoryboard * storyboard;
@property (nonatomic) BOOL isDisplay;
@property (nonatomic) NSWindowController * controller;
@end

@implementation ASCPresentationReporter

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _storyboard = [NSStoryboard storyboardWithName:@"Presentation-Reporter" bundle:[NSBundle mainBundle]];
        _isDisplay = false;
    }
    
    return self;
}

- (void)create:(void *)data {
    if (_isDisplay || !_storyboard) {
        return;
    }
    
    _controller = [_storyboard instantiateControllerWithIdentifier:@"PresentationWindowController"];
    
    if (_controller) {
        _isDisplay = true;
        
        NSCefView * cefView = [[NSCefView alloc] initWithFrame:CGRectZero];
        CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
        
        if (cefView && appManager) {
            _controller.window.delegate = self;
            
            [_controller.contentViewController.view addSubview:cefView];
            [cefView setupFillConstraints];
            
            [_controller showWindow:nil];
            
            NSEditorApi::CAscReporterCreate * pData = (NSEditorApi::CAscReporterCreate *)data;
            CAscReporterData * pCreateData = reinterpret_cast<CAscReporterData *>(pData->get_Data());
            pData->put_Data(NULL);
            
            [cefView createReporter:appManager data:pCreateData];
        }
    }
}

- (void)destroy {
    if (!_isDisplay || !_controller) {
        return;
    }
    
    [_controller close];
    _isDisplay = false;
}

- (void)apply:(void *)event {
    CAscApplicationManager * appManager = [NSAscApplicationWorker getAppManager];
    NSEditorApi::CAscMenuEvent * pEvent = (NSEditorApi::CAscMenuEvent *)event;
    NSEditorApi::CAscReporterMessage * pData = (NSEditorApi::CAscReporterMessage *)pEvent->m_pData;
    
    CCefView * cefView = appManager->GetViewById(pData->get_ReceiverId());
    
    if (cefView) {
        pEvent->AddRef();
        cefView->Apply(pEvent);
    }
}

- (NSCefView *)cefView {
    if (!_controller) {
        return nil;
    }
    
    for (NSView * view in _controller.contentViewController.view.subviews) {
        if ([view isKindOfClass:[NSCefView class]]) {
            return (NSCefView *)view;
        }
    }
    return nil;
}

// MARK: - NSWindow Delegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
    // TODO: Stop Slideshow
    return true;
}

@end