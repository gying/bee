                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             //
//  ContectsTableViewCell.m
//  Agree
//
//  Created by G4ddle on 15/3/19.
//  Copyright (c) 2015年 superRabbit. All rights reserved.
//

#import "ContactsTableViewCell.h"
#import "UIButton+WebCache.h"
#import "SRImageManager.h"
#import <SDWebImageManager.h>

@implementation ContactsTableViewCell {
    Model_User *_user;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initWithUser: (Model_User *)user {
    _user = user;
    [self.avatarButton.layer setCornerRadius:self.avatarButton.frame.size.height/2];
    [self.avatarButton.layer setMasksToBounds:YES];
    
    [self.avatarButton addTarget:self action:@selector(tapAvatarButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //下载图片
    NSURL *imageUrl = [SRImageManager miniAvatarImageFromOSS:user.avatar_path];

    [self.avatarButton sd_setBackgroundImageWithURL:imageUrl forState:UIControlStateNormal];
    [self.nicknameLabel setText:user.nickname];
    
    
    if (0 != user.chat_update.intValue) {
        [self.countLabel setHidden:NO];
        [self.countLabel setText:[user.chat_update stringValue]];
    } else {
        [self.countLabel setHidden:YES];
    }
    
    if (!user.surplus) {
        [self.surplusLabel setHidden:YES];
    } else {
        [self.surplusLabel setHidden:NO];
        [self.surplusLabel setText:[NSString stringWithFormat:@"未收: %d元", user.surplus.intValue]];
    }
    
    if (!user.overdraft) {
        [self.overdraftLabel setHidden:YES];
    } else {
        [self.overdraftLabel setHidden:NO];
        [self.overdraftLabel setText:[NSString stringWithFormat:@"欠款: %d元", user.overdraft.intValue]];
    }
}

//点击好友头像
- (void)tapAvatarButton: (UIButton *)sender {
    
    if (self.topViewController) {
        if (![_user.pk_user isEqual:[Model_User loadFromUserDefaults].pk_user]) {
            [self.topViewController.accountView show];
            [self.topViewController.accountView loadWithUser:_user withGroup:nil];
        }
    }
}



@end
