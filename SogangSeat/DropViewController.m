//
//  DropViewController.m
//  SogangSeat
//
//  Created by Baekjoon Choi on 6/10/14.
//  Copyright (c) 2014 Baekjoon Choi. All rights reserved.
//

#import "DropViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface DropViewController ()

@end

@implementation DropViewController {
    NSMutableArray *_listArray;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _listArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectZero];
    [refreshControl sizeToFit];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self downloadStart];
}

-(void)handleRefresh:(UIRefreshControl *)refreshControl {
    [self downloadStart];
    [refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _listArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // Configure the cell...
    NSArray *arr = _listArray[indexPath.row];
    UILabel *label = (UILabel *)[cell viewWithTag:100];
    label.text = arr[0];
    label = (UILabel *)[cell viewWithTag:101];
    label.text = [NSString stringWithFormat:@"10분: %@ 20분: %@ 30분: %@ 40분: %@ 50분: %@ 60분: %@", arr[1],arr[2],arr[3],arr[4],arr[5],arr[6]];
    return cell;

}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:&error];
    return regex;
}

-(void)parseTable:(NSString *)table andType:(NSString *)linkType{
    //    NSLog(@"%@",table);
    NSRegularExpression *regex = [self regularExpressionWithPattern:@"<tr.*?>.*?</tr>"];
    NSArray *trs = [regex matchesInString:table options:0 range:NSMakeRange(0, table.length)];
    if (trs.count <= 2) return;
    trs = [trs subarrayWithRange:NSMakeRange(2, trs.count-2)];
//    NSLog(@"%d",trs.count);
    for (NSTextCheckingResult *trResult in trs) {
        NSMutableString *tr = [[table substringWithRange:trResult.range] mutableCopy];
        regex = [self regularExpressionWithPattern:@"<tr.*?>|</tr>"];
        [regex replaceMatchesInString:tr options:0 range:NSMakeRange(0, tr.length) withTemplate:@""];
//        NSLog(@"%@",tr);
        [tr replaceOccurrencesOfString:@"</td>" withString:@"|" options:NSCaseInsensitiveSearch range:NSMakeRange(0, tr.length)];
        regex = [self regularExpressionWithPattern:@"<.*?>"];
        [regex replaceMatchesInString:tr options:0 range:NSMakeRange(0, tr.length) withTemplate:@""];
        [tr replaceOccurrencesOfString:@"&nbsp;" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, tr.length)];
        NSArray *tds = [tr componentsSeparatedByString:@"|"];
//        NSLog(@"%d",tds.count);
        if (tds.count == 8) {
            NSMutableArray *ans = [NSMutableArray arrayWithCapacity:7];
            for (int i=0; i<7; i++) {
                NSString *td = [(NSString *)tds[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [ans addObject:td];
            }
            [_listArray addObject:ans];
        }

    }
}

-(void)parseResult:(NSData *)data andType:(NSString *)linkType{
    NSString *s = [[NSString alloc] initWithData:data encoding:0x80000000 + kCFStringEncodingDOSKorean];
    
    NSRegularExpression *regex = [self regularExpressionWithPattern:@"<table.*?</table>"];
    
    NSArray *match = [regex matchesInString:s options:0 range:NSMakeRange(0, s.length)];
    if (match.count != 4) return;
    NSTextCheckingResult *t1 = match[3];
    
    [self parseTable:[s substringWithRange:t1.range] andType:linkType];
}

-(void)downloadStart {
    [_listArray removeAllObjects];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    NSURL *url = [NSURL URLWithString:@"http://libseat.sogang.ac.kr/seat/domian5.asp"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parseResult:responseObject andType:@"seat"];
        NSURL *url2 = [NSURL URLWithString:@"http://libseat.sogang.ac.kr/seatj/domian5.asp"];
        NSURLRequest *request2 = [NSURLRequest requestWithURL:url2];
        
        AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:request2];
        
        operation2.responseSerializer = [AFHTTPResponseSerializer serializer];
        [operation2 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self parseResult:responseObject andType:@"seatj"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            });
        }];
        [operation2 start];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        });
    }];
    [operation start];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
