//
//  GroupCollectionViewCell.m
//  Agree
//
//  Created by G4ddle on 15/2/14.
//  Copyright (c) 2015年 superRabbit. All rights reserved.
//

#import "GroupCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "SRImageManager.h"


@implementation GroupCollectionViewCell


- (void)initCellWithGroup: (Model_Group *)group isAddView: (BOOL)isAddView {
    if (!self.initDone) {
        
        self.groupView.layer.shadowColor = [UIColor grayColor].CGColor;
        self.groupView.layer.shadowOffset = CGSizeMake(0, 0);
        self.groupView.layer.shadowOpacity = 0.5;
        self.groupView.layer.cornerRadius = 3;
        self.groupView.layer.shadowRadius = 1.5;
        
        [self.group2ndView.layer setMasksToBounds:YES];
        [self.group2ndView.layer setCornerRadius:3];
        
        [self.statusView.layer setCornerRadius:self.statusView.frame.size.height/2];
        [self.statusView.layer setMasksToBounds:YES];
        
        self.initDone = YES;
    }
    
    
//    self.groupImageView.image = nil;
    if (isAddView) {
        self.lineView.hidden = YES;
        self.groupImageView.image = [UIImage imageNamed:@"agree_add_icon"];
        [self.groupImageView setContentMode:UIViewContentModeCenter];
        [self.statusView setHidden:YES];
        
        self.groupNameLabel.text = @"添加新的小组";

        [self.groupView setAlpha:0.3];
        [self.groupImageView setBackgroundColor:[UIColor whiteColor]];
        
    } else {
        [self.groupImageView setContentMode:UIViewContentModeScaleToFill];
        self.lineView.hidden = NO;
        
        if (0 != group.party_update.intValue || 0 != group.chat_update.intValue || 0 != group.photo_update.intValue) {
            [self.statusView setHidden:NO];
        } else {
            [self.statusView setHidden:YES];
        }
        self.groupNameLabel.text = group.name;
        [self.groupView setAlpha:1.0];
        
        //读取小组封面
        [self.groupImageView sd_setImageWithURL:[SRImageManager groupFrontCoverImageImageFromOSS:group.avatar_path]
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                            [self.groupImageView setImage:image];
                                        }];
    }
}

- (void)initAddView {
    self.lineView.hidden = YES;
    self.groupImageView.image = [UIImage imageNamed:@"agree_add_icon"];
    [self.groupImageView setContentMode:UIViewContentModeCenter];
    [self.statusView setHidden:YES];
    
    self.groupNameLabel.text = @"添加新的小组";
    
    self.groupView.layer.shadowColor = [UIColor grayColor].CGColor;
    self.groupView.layer.shadowOffset = CGSizeMake(0, 0);
    self.groupView.layer.shadowOpacity = 0.5;
    self.groupView.layer.cornerRadius = 3;
    self.groupView.layer.shadowRadius = 1.5;
    
    [self.groupView setAlpha:0.3];
    
    [self.group2ndView.layer setMasksToBounds:YES];
    [self.group2ndView.layer setCornerRadius:3];
    
    [self.groupImageView setBackgroundColor:[UIColor whiteColor]];
}

@end
