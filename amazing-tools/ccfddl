#!/usr/bin/env python3
"""
CCF DDL AI Conference Tracker
A CLI tool to check upcoming AI conference deadlines
"""

import argparse
import json
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import requests
from dataclasses import dataclass, asdict
from tabulate import tabulate
import colorama
from colorama import Fore, Style

# Initialize colorama for cross-platform colored output
colorama.init()

@dataclass
class Conference:
    """Conference data structure"""
    name: str
    full_name: str
    ccf_rank: str
    deadline: str
    notification: str
    conference_date: str
    location: str
    website: str
    categories: List[str]
    
    def days_until_deadline(self) -> int:
        """Calculate days until deadline"""
        try:
            deadline_date = datetime.strptime(self.deadline, "%Y-%m-%d")
            today = datetime.now()
            return (deadline_date - today).days
        except ValueError:
            return -999  # Invalid date format

class CCFDDLTracker:
    """Main CCF DDL tracking class"""
    
    def __init__(self):
        self.conferences = []
        self.load_conference_data()
    
    def load_conference_data(self):
        """Load conference data from local storage or web API"""
        # For demo purposes, using hardcoded data
        # In production, this would fetch from CCF DDL API or local database
        sample_conferences = [
            {
                "name": "AAAI",
                "full_name": "AAAI Conference on Artificial Intelligence",
                "ccf_rank": "A",
                "deadline": "2025-08-15",
                "notification": "2025-11-30",
                "conference_date": "2026-02-25",
                "location": "Philadelphia, USA",
                "website": "https://aaai.org/conference/aaai/aaai-26/",
                "categories": ["AI", "Machine Learning"]
            },
            {
                "name": "ICML",
                "full_name": "International Conference on Machine Learning",
                "ccf_rank": "A",
                "deadline": "2025-01-31",
                "notification": "2025-05-15",
                "conference_date": "2025-07-21",
                "location": "Vienna, Austria",
                "website": "https://icml.cc/",
                "categories": ["Machine Learning", "Deep Learning"]
            },
            {
                "name": "NeurIPS",
                "full_name": "Conference on Neural Information Processing Systems",
                "ccf_rank": "A",
                "deadline": "2025-05-22",
                "notification": "2025-09-25",
                "conference_date": "2025-12-09",
                "location": "Vancouver, Canada",
                "website": "https://neurips.cc/",
                "categories": ["Neural Networks", "Machine Learning"]
            },
            {
                "name": "ICLR",
                "full_name": "International Conference on Learning Representations",
                "ccf_rank": "A",
                "deadline": "2025-09-28",
                "notification": "2026-01-15",
                "conference_date": "2026-04-27",
                "location": "Singapore",
                "website": "https://iclr.cc/",
                "categories": ["Deep Learning", "Representation Learning"]
            },
            {
                "name": "IJCAI",
                "full_name": "International Joint Conference on Artificial Intelligence",
                "ccf_rank": "A",
                "deadline": "2025-01-20",
                "notification": "2025-04-30",
                "conference_date": "2025-08-19",
                "location": "Montreal, Canada",
                "website": "https://ijcai.org/",
                "categories": ["AI", "Reasoning"]
            },
            {
                "name": "CVPR",
                "full_name": "Conference on Computer Vision and Pattern Recognition",
                "ccf_rank": "A",
                "deadline": "2025-11-15",
                "notification": "2026-02-28",
                "conference_date": "2026-06-21",
                "location": "Seattle, USA",
                "website": "https://cvpr.org/",
                "categories": ["Computer Vision", "Pattern Recognition"]
            },
            {
                "name": "ICCV",
                "full_name": "International Conference on Computer Vision",
                "ccf_rank": "A",
                "deadline": "2025-03-07",
                "notification": "2025-07-15",
                "conference_date": "2025-10-06",
                "location": "Hawaii, USA",
                "website": "https://iccv.org/",
                "categories": ["Computer Vision", "Image Processing"]
            },
            {
                "name": "ECCV",
                "full_name": "European Conference on Computer Vision",
                "ccf_rank": "B",
                "deadline": "2025-03-14",
                "notification": "2025-07-01",
                "conference_date": "2025-09-29",
                "location": "Milano, Italy",
                "website": "https://eccv.org/",
                "categories": ["Computer Vision", "Machine Learning"]
            }
        ]
        
        self.conferences = [Conference(**conf) for conf in sample_conferences]
    
    def get_upcoming_deadlines(self, days_ahead: int = 90) -> List[Conference]:
        """Get conferences with deadlines in the next N days"""
        upcoming = []
        for conf in self.conferences:
            days_until = conf.days_until_deadline()
            if 0 <= days_until <= days_ahead:
                upcoming.append(conf)
        
        # Sort by deadline
        upcoming.sort(key=lambda x: x.days_until_deadline())
        return upcoming
    
    def get_conferences_by_rank(self, rank: str) -> List[Conference]:
        """Filter conferences by CCF rank"""
        return [conf for conf in self.conferences if conf.ccf_rank.upper() == rank.upper()]
    
    def get_conferences_by_category(self, category: str) -> List[Conference]:
        """Filter conferences by category"""
        return [conf for conf in self.conferences 
                if any(category.lower() in cat.lower() for cat in conf.categories)]
    
    def format_conference_table(self, conferences: List[Conference], show_details: bool = False) -> str:
        """Format conferences as a table"""
        if not conferences:
            return f"{Fore.YELLOW}No conferences found matching your criteria.{Style.RESET_ALL}"
        
        headers = ["Conference", "CCF", "Deadline", "Days Left", "Location"]
        if show_details:
            headers.extend(["Notification", "Conference Date", "Categories"])
        
        table_data = []
        for conf in conferences:
            days_left = conf.days_until_deadline()
            
            # Color coding for urgency
            if days_left < 0:
                deadline_color = Fore.RED
                status = "PASSED"
            elif days_left <= 7:
                deadline_color = Fore.RED
                status = f"{days_left}d"
            elif days_left <= 30:
                deadline_color = Fore.YELLOW
                status = f"{days_left}d"
            else:
                deadline_color = Fore.GREEN
                status = f"{days_left}d"
            
            # CCF rank color
            rank_color = Fore.CYAN if conf.ccf_rank == 'A' else Fore.MAGENTA
            
            row = [
                f"{Fore.BLUE}{conf.name}{Style.RESET_ALL}",
                f"{rank_color}{conf.ccf_rank}{Style.RESET_ALL}",
                conf.deadline,
                f"{deadline_color}{status}{Style.RESET_ALL}",
                conf.location
            ]
            
            if show_details:
                row.extend([
                    conf.notification,
                    conf.conference_date,
                    ", ".join(conf.categories)
                ])
            
            table_data.append(row)
        
        return tabulate(table_data, headers=headers, tablefmt="grid")
    
    def show_conference_details(self, conference_name: str):
        """Show detailed information about a specific conference"""
        conf = next((c for c in self.conferences 
                    if c.name.lower() == conference_name.lower()), None)
        
        if not conf:
            print(f"{Fore.RED}Conference '{conference_name}' not found.{Style.RESET_ALL}")
            return
        
        print(f"\n{Fore.CYAN}=== {conf.name} - {conf.full_name} ==={Style.RESET_ALL}")
        print(f"CCF Rank: {Fore.CYAN}{conf.ccf_rank}{Style.RESET_ALL}")
        print(f"Deadline: {Fore.YELLOW}{conf.deadline}{Style.RESET_ALL} ({conf.days_until_deadline()} days left)")
        print(f"Notification: {conf.notification}")
        print(f"Conference Date: {conf.conference_date}")
        print(f"Location: {conf.location}")
        print(f"Website: {Fore.BLUE}{conf.website}{Style.RESET_ALL}")
        print(f"Categories: {', '.join(conf.categories)}")
        print()

def main():
    """Main CLI function"""
    parser = argparse.ArgumentParser(
        description="CCF DDL AI Conference Tracker - Check upcoming AI conference deadlines",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Show upcoming deadlines
  %(prog)s --days 30                # Show deadlines in next 30 days
  %(prog)s --rank A                 # Show only CCF-A conferences
  %(prog)s --category vision        # Show computer vision conferences
  %(prog)s --details AAAI           # Show details for AAAI conference
  %(prog)s --list                   # List all conferences
        """
    )
    
    parser.add_argument(
        "--days", "-d",
        type=int,
        default=90,
        help="Show deadlines in the next N days (default: 90)"
    )
    
    parser.add_argument(
        "--rank", "-r",
        choices=['A', 'B', 'C'],
        help="Filter by CCF rank (A, B, or C)"
    )
    
    parser.add_argument(
        "--category", "-c",
        help="Filter by category (e.g., vision, learning, AI)"
    )
    
    parser.add_argument(
        "--details", "-i",
        help="Show detailed information about a specific conference"
    )
    
    parser.add_argument(
        "--list", "-l",
        action="store_true",
        help="List all conferences with details"
    )
    
    parser.add_argument(
        "--urgent", "-u",
        action="store_true",
        help="Show only urgent deadlines (next 7 days)"
    )
    
    args = parser.parse_args()
    
    tracker = CCFDDLTracker()
    
    # Handle specific conference details
    if args.details:
        tracker.show_conference_details(args.details)
        return
    
    # Get conferences based on filters
    conferences = tracker.conferences
    
    if args.rank:
        conferences = tracker.get_conferences_by_rank(args.rank)
    
    if args.category:
        conferences = tracker.get_conferences_by_category(args.category)
    
    if args.urgent:
        conferences = [c for c in conferences if 0 <= c.days_until_deadline() <= 7]
    elif not args.list:
        conferences = [c for c in conferences if c.days_until_deadline() >= 0]
        conferences = sorted(conferences, key=lambda x: x.days_until_deadline())[:10]
    
    # Filter by days if not showing all
    if not args.list and not args.urgent:
        conferences = [c for c in conferences if c.days_until_deadline() <= args.days]
    
    # Display results
    if args.list:
        print(f"\n{Fore.CYAN}=== All AI Conferences ==={Style.RESET_ALL}")
        print(tracker.format_conference_table(conferences, show_details=True))
    elif args.urgent:
        print(f"\n{Fore.RED}=== Urgent Deadlines (Next 7 Days) ==={Style.RESET_ALL}")
        print(tracker.format_conference_table(conferences))
    else:
        print(f"\n{Fore.CYAN}=== Upcoming AI Conference Deadlines ==={Style.RESET_ALL}")
        print(tracker.format_conference_table(conferences))
    
    # Show summary
    total_upcoming = len([c for c in tracker.conferences if c.days_until_deadline() >= 0])
    urgent_count = len([c for c in tracker.conferences if 0 <= c.days_until_deadline() <= 7])
    
    print(f"\n{Fore.CYAN}Summary:{Style.RESET_ALL}")
    print(f"Total upcoming deadlines: {total_upcoming}")
    print(f"Urgent deadlines (≤7 days): {Fore.RED}{urgent_count}{Style.RESET_ALL}")
    print(f"Displayed: {len(conferences)}")

if __name__ == "__main__":
    main()
