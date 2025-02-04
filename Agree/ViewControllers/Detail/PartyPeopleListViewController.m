//
//  PartyPeopleListViewController.m
//  Agree
//
//  Created by G4ddle on 15/2/25.
//  Copyright (c) 2015年 superRabbit. All rights reserved.
//

#import "PartyPeopleListViewController.h"
#import "Model_User.h"
#import "PeopleListTableViewCell.h"
#import "SRNet_Manager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SRTool.h"

#define AgreeBlue [UIColor colorWithRed:82/255.0 green:213/255.0 blue:204/255.0 alpha:1.0]

@interface PartyPeopleListViewController () <UITableViewDataSource, UITableViewDelegate,UIScrollViewDelegate> {
    NSMutableArray *_inArray;
    NSMutableArray *_outArray;
    NSMutableArray *_unknowArray;
    NSMutableArray *_showArray;
    
    NSMutableArray *_tempInArray;
    BOOL _inArrayIsChange;
}

@end

@implementation PartyPeopleListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setRelationData];
    
    [self.inButton.layer setCornerRadius:self.inButton.frame.size.height/2];
    [self.outButton.layer setCornerRadius:self.outButton.frame.size.height/2];
    [self.unknowButton.layer setCornerRadius:self.unknowButton.frame.size.height/2];
    
    [self.inLabel setText:[NSString stringWithFormat:@"%d", (int)_inArray.count]];
    [self.outLabel setText:[NSString stringWithFormat:@"%d", (int)_outArray.count]];
    [self.unknowLabel setText:[NSString stringWithFormat:@"%d", (int)_unknowArray.count]];
    
    [self.peoplesTableview setDelegate:self];
    [self.peoplesTableview setDataSource:self];
    
    switch (self.showStatus) {
        case 1:{
            [self pressedTheInButton:Nil];
            _showArray = _inArray;
        }
            break;
            
        case 2: {
            [self pressedTheOutButton:Nil];
            _showArray = _outArray;
        }
            break;
            
        case 3: {
            [self pressedTheUnknowButton:Nil];
            _showArray = _unknowArray;
        }
            break;
            
        default:
            break;
    }
}

- (void)setRelationData {
    _inArray = [[NSMutableArray alloc] init];
    _outArray = [[NSMutableArray alloc] init];
    _unknowArray = [[NSMutableArray alloc] init];
    
    _tempInArray = [[NSMutableArray alloc] init];
    
    if (self.relationArray) {
        for (Model_User *theUser in self.relationArray) {
            switch ([theUser.relationship intValue]) {
                case 1: {
                    //参与用户
                    [_inArray addObject:theUser];
                    
                    Model_User *user = [[Model_User alloc] init];
                    user.pk_user = theUser.pk_user;
                    user.pay_type = theUser.pay_type;
                    [_tempInArray addObject:user];
                }
                    break;
                case 2: {
                    //拒绝用户
                    [_outArray addObject:theUser];
                }
                    break;
                case 0: {
                    //未表态用户
                    [_unknowArray addObject:theUser];
                }
                    break;
                default:
                    break;
            }
        }
    }
}

- (IBAction)pressedTheInButton:(id)sender {
    self.showStatus = 1;
    
    [self resetAllButton];
    [self.inButton setBackgroundColor:AgreeBlue];
    [self.inButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.inLabel setTextColor:[UIColor whiteColor]];
    
    _showArray = _inArray;
    [self.peoplesTableview reloadData];
}
- (IBAction)pressedTheUnknowButton:(id)sender {
    self.showStatus = 2;
    
    [self resetAllButton];
    [self.unknowButton setBackgroundColor:AgreeBlue];
    [self.unknowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.unknowLabel setTextColor:[UIColor whiteColor]];
    
    _showArray = _unknowArray;
    [self.peoplesTableview reloadData];
}
- (IBAction)pressedTheOutButton:(id)sender {
    self.showStatus = 3;
    [self resetAllButton];
    [self.outButton setBackgroundColor:AgreeBlue];
    [self.outButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.outLabel setTextColor:[UIColor whiteColor]];
    
    _showArray = _outArray;
    [self.peoplesTableview reloadData];
}

- (void)resetAllButton {
    [self.inButton setBackgroundColor:[UIColor clearColor]];
    [self.inButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.inLabel setTextColor:AgreeBlue];
    
    [self.outButton setBackgroundColor:[UIColor clearColor]];
    [self.outButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.outLabel setTextColor:AgreeBlue];
    
    [self.unknowButton setBackgroundColor:[UIColor clearColor]];
    [self.unknowButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.unknowLabel setTextColor:AgreeBlue];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_showArray) {
        return _showArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Model_User *theUser = [_showArray objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"peopleListCell";
    
    PeopleListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (nil == cell) {
        cell = [[PeopleListTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    if (!theUser.pay_amount) {
        if (self.party.pay_amount) {
            theUser.pay_amount = self.party.pay_amount;
        }
    }
    [cell initWithUser:theUser withShowStatus:self.showStatus isCreator:self.isCreator isPayor:self.isPayor];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)tapBackButton:(id)sender {
    //首先做是否更改状态的判断
    for (Model_User *tempUser in _tempInArray) {
        for (Model_User *user in _inArray) {
            if (!tempUser.pay_type) {
                tempUser.pay_type = @0;
            }
            if ([user.pk_user isEqualToNumber:tempUser.pk_user]) {
                if (!(tempUser.pay_type.intValue == user.pay_type.intValue)) {
                    //未被改变过
                    _inArrayIsChange = YES;
                }
            }
        }
    }
    
    if (_inArrayIsChange) {
        [SRTool showSRSheetInView:self.view withTitle:@"提示"
                          message:@"是否保存当前更改的信息?"
                  withButtonArray:@[@"保存退出", @"不保存,直接退出"]
                  tapButtonHandle:^(int buttonIndex) {
                      switch (buttonIndex) {
                          case 0: {
                              //保存后退出
                              [SVProgressHUD showWithStatus:@"正在保存支付信息" maskType:SVProgressHUDMaskTypeGradient];
                              NSMutableArray *relationAry = [[NSMutableArray alloc] init];
                              for (Model_User *user in self.relationArray) {
                                  Model_Party_User *partyRealtion = [[Model_Party_User alloc] init];
                                  partyRealtion.pk_party_user = user.pk_party_user;
                                  partyRealtion.pay_type = user.pay_type;
                                  if (self.party.pay_fk_user) {
                                      partyRealtion.pay_fk_user = self.party.pay_fk_user;
                                  } else {
                                      partyRealtion.pay_fk_user = self.party.fk_user;
                                  }
                                  
                                  [relationAry addObject:partyRealtion];
                              }
                              
                              //点击保存按钮,开始保存数据
                              [SRNet_Manager requestNetWithDic:[SRNet_Manager updatePartyRelationships:relationAry]
                                                      complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                                          //保存操作成功
                                                          [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                                                          [self.navigationController popViewControllerAnimated:YES];
                                                      } failure:^(NSError *error, NSURLSessionDataTask *task) {
                                                          [self.navigationController popViewControllerAnimated:YES];
                                                      }];
                          }
                              break;
                          case 1: {
                              //直接退出
                              //需要将更改数组恢复原有属性
                              for (Model_User *tempUser in _tempInArray) {
                                  for (Model_User *user in _inArray) {
                                      if ([user.pk_user isEqualToNumber:tempUser.pk_user]) {
                                          user.pay_type = tempUser.pay_type;
                                      }
                                  }
                              }
                              [self.navigationController popViewControllerAnimated:YES];
                          }
                              break;
                          default:
                              break;
                      }
                  } tapCancelHandle:^{
                      
                  }];
        
        
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)tapSaveButton:(UIButton *)sender {
    //开始初始化关系数组
    [SVProgressHUD showWithStatus:@"正在保存支付信息" maskType:SVProgressHUDMaskTypeGradient];
    NSMutableArray *relationAry = [[NSMutableArray alloc] init];
    for (Model_User *user in self.relationArray) {
        Model_Party_User *partyRealtion = [[Model_Party_User alloc] init];
        partyRealtion.pk_party_user = user.pk_party_user;
        partyRealtion.pay_type = user.pay_type;
        [relationAry addObject:partyRealtion];
    }
    
    
    //点击保存按钮,开始保存数据
    [SRNet_Manager requestNetWithDic:[SRNet_Manager updatePartyRelationships:relationAry]
                            complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                //保存操作成功
                                //保存成功将更新临时数组属性
                                for (Model_User *tempUser in _tempInArray) {
                                    for (Model_User *user in _inArray) {
                                        if ([user.pk_user isEqualToNumber:tempUser.pk_user]) {
                                            tempUser.pay_type = [NSNumber numberWithInteger:user.pay_type.integerValue];
                                        }
                                    }
                                }
                                
                                
                                [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                            } failure:^(NSError *error, NSURLSessionDataTask *task) {
                                
                            }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
